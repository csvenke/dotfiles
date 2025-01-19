from anthropic import Anthropic
from halo import Halo


class Claude:
    def __init__(self, api_key: str | None):
        if not api_key:
            raise ValueError("Missing anthropic api key")

        self.client = Anthropic(api_key=api_key)

    @Halo(text="Thinking", spinner="dots")
    def message(self, prompt: str) -> str:
        message = self.client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1024,
            messages=[{"role": "user", "content": prompt}],
        )
        text = getattr(message.content[0], "text", "")

        return text
