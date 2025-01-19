from setuptools import setup

setup(
    name="llm",
    version="1.0.0",
    packages=["."],
    entry_points={
        "console_scripts": [
            "llm=script:main",
        ],
    },
)
