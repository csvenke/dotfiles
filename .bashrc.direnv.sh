if ! command -v direnv >/dev/null; then
	return
fi

export DIRENV_LOG_FORMAT=
export DIRENV_WARN_TIMEOUT=1m

eval "$(direnv hook bash)"
