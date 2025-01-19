from setuptools import setup

setup(
    name="dotstrap",
    version="1.0.0",
    packages=["."],
    entry_points={
        "console_scripts": [
            "dotstrap=main:main",
        ],
    },
)
