function restore_app() {
	if [ -d $(deps_backup_path) ]; then
		cp -pR $(deps_backup_path) ${build_path}/deps
	fi

	if [ $erlang_changed != true ] && [ $erlang_changed != true ]; then
		if [ -d $(build_backup_path) ]; then
			cp -pR $(build_backup_path) ${build_path}/_build
		fi
	fi
}

function app_dependencies() {
	# Unset this var so that if the parent dir is a git repo, it isn't detected
	# And all git operations are performed on the respective repos
	local git_dir_value=$GIT_DIR
	unset GIT_DIR

	cd $build_path
	# output_section "Fetching app dependencies with mix"
	# mix deps.get --only $MIX_ENV || exit 1

	export GIT_DIR=$git_dir_value
	cd - >/dev/null
}

function backup_app() {
	# Delete the previous backups
	rm -rf $(deps_backup_path) $(build_backup_path)

	cp -pR ${build_path}/deps $(deps_backup_path)
	cp -pR ${build_path}/_build $(build_backup_path)
}

function compile_app() {
	local git_dir_value=$GIT_DIR
	unset GIT_DIR

	cd $build_path
	output_section "Compiling"
	mix compile --force || exit 1

	mix deps.clean --unused

	export GIT_DIR=$git_dir_value
	cd - >/dev/null
}

function post_compile_hook() {
	cd $build_path

	if [ -n "$post_compile" ]; then
		output_section "Executing DEPRECATED post compile: $post_compile"
		$post_compile || exit 1
	fi

	cd - >/dev/null
}

function pre_compile_hook() {
	cd $build_path

	if [ -n "$pre_compile" ]; then
		output_section "Executing DEPRECATED pre compile: $pre_compile"
		$pre_compile || exit 1
	fi

	cd - >/dev/null
}

function write_profile_d_script() {
	output_section "Creating .profile.d with env vars"
	mkdir -p $build_path/.profile.d

	local export_line="export PATH=\$HOME/.platform_tools:\$HOME/.platform_tools/erlang/bin:\$HOME/.platform_tools/erlang/bin:\$PATH
    export LC_CTYPE=en_US.utf8"

	# Only write MIX_ENV to profile if the application did not set MIX_ENV
	if [ ! -f $env_path/MIX_ENV ]; then
		export_line="${export_line}
        export MIX_ENV=${MIX_ENV}"
	fi

	echo $export_line >>$build_path/.profile.d/erlang_buildpack_paths.sh
}

function write_export() {
	output_section "Writing export for multi-buildpack support"

	local export_line="export PATH=$(platform_tools_path):$(erlang_path)/bin:$(erlang_path)/bin:\$PATH
    export LC_CTYPE=en_US.utf8"

	# Only write MIX_ENV to export if the application did not set MIX_ENV
	if [ ! -f $env_path/MIX_ENV ]; then
		export_line="${export_line}
        export MIX_ENV=${MIX_ENV}"
	fi

	echo $export_line >$build_pack_path/export
}
