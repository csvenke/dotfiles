import { makeCompactTidy } from "../compact.ts";
import type { TidyStrategy } from "../shared.ts";

export const bashTidy: TidyStrategy = makeCompactTidy({});
