from anthropic import Anthropic
from halo import Halo


class Claude:
    def __init__(self, model: str | None, api_key: str | None):
        if not model:
            raise ValueError("Missing model")
        if not api_key:
            raise ValueError("Missing anthropic api key")

        self.model = model
        self.client = Anthropic(api_key=api_key)

    @Halo(text="Thinking", spinner="dots")
    def message(
        self,
        prompt: str,
        max_tokens: int = 1024,
        temperature: float = 0.7,
    ) -> str:
        message = self.client.messages.create(
            model=self.model,
            max_tokens=max_tokens,
            temperature=temperature,
            messages=[{"role": "user", "content": prompt}],
        )
        text = getattr(message.content[0], "text", "")

        return text
