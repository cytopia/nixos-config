git-ident-show() {
	printf "user   %s\n" "$(git config --get user.name)"
	printf "mail   %s\n" "$(git config --get user.email)"
	printf "key    %s\n" "$(git config --get user.signingkey)"
}

repo() {
	specific="${1:-}"

	if [ "${#}" = "1" ]; then
		cd "${HOME}/repo/${1}"*
	elif [ "${#}" = "2" ]; then
		cd "${HOME}/repo/${1}"*/"${2}"*
	else
		cd "${HOME}/repo/cytopia"
	fi
}

notes() {
	specific="${1:-}"
	tmp="${HOME}/.cache/notes"

	# Defaults
	path="${HOME}/notes"
	name=
	lock=

	# Create tmp dir
	if [ ! -d "${tmp}" ]; then
		mkdir -p "${tmp}"
	fi

	# Try to get the specific directory
	if [ "${specific}" = "" ]; then
		path="${path}/private"
		name="private"
		lock="${tmp}/${name}.lock"
	else
		for d in ${path}/${specific}*; do
			if [ -d "${d}" ]; then
				path="${d}"
				name="$( basename "${path}" )"
				lock="${tmp}/${name}.lock"
			fi
			# Only try first match
			break;
		done
	fi

	# Check if it is already running
	if [ -f "${lock}" ]; then
		echo "notes (${name}) already running..."
		return 1
	fi

	# Lock
	touch "${lock}"

	cd "${path}"
	if [ "${name}" = "private" ]; then
		${EDITOR:-vim} -o TODO.md
	else
		${EDITOR:-vim} -o TODO.md
	fi

	# Unlock
	rm -f "${lock}"
}
