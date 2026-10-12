/**
 * Minimal PNG encoder (8-bit RGBA, no interlace, filter 0) using node's zlib.
 * Just enough to hand composed board pixels to the kitty image protocol.
 */

import { deflateSync } from "node:zlib";

const CRC_TABLE = (() => {
  const table = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) {
      c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    }
    table[n] = c >>> 0;
  }
  return table;
})();

function crc32(buf: Uint8Array): number {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) {
    c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  }
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type: string, data: Uint8Array): Uint8Array {
  const out = new Uint8Array(12 + data.length);
  const view = new DataView(out.buffer);
  view.setUint32(0, data.length);
  const typeBytes = new TextEncoder().encode(type);
  out.set(typeBytes, 4);
  out.set(data, 8);
  const crcInput = out.subarray(4, 8 + data.length);
  view.setUint32(8 + data.length, crc32(crcInput));
  return out;
}

/** Encode raw RGBA pixels as a PNG. */
export function encodePng(
  rgba: Uint8Array,
  width: number,
  height: number,
): Uint8Array {
  if (rgba.length !== width * height * 4) {
    throw new Error(
      `encodePng: expected ${width * height * 4} bytes, got ${rgba.length}`,
    );
  }
  const ihdr = new Uint8Array(13);
  const view = new DataView(ihdr.buffer);
  view.setUint32(0, width);
  view.setUint32(4, height);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // color type RGBA
  // compression 0, filter 0, interlace 0

  const stride = width * 4;
  const raw = new Uint8Array((stride + 1) * height);
  for (let y = 0; y < height; y++) {
    // filter type 0 byte is already 0
    raw.set(rgba.subarray(y * stride, (y + 1) * stride), y * (stride + 1) + 1);
  }
  const idat = deflateSync(raw, { level: 1 });

  const signature = Uint8Array.from([
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
  ]);
  const out = new Uint8Array(
    signature.length + (12 + 13) + (12 + idat.length) + 12,
  );
  let offset = 0;
  out.set(signature, offset);
  offset += signature.length;
  out.set(chunk("IHDR", ihdr), offset);
  offset += 12 + 13;
  out.set(chunk("IDAT", idat), offset);
  offset += 12 + idat.length;
  out.set(chunk("IEND", new Uint8Array(0)), offset);
  return out;
}
