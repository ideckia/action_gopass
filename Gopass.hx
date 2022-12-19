package;

import haxe.ds.Option;

using api.IdeckiaApi;

typedef Props = {
	@:editable("The name of the secret to retrieve")
	var secret_name:String;
	@:editable("The separator between username and password stored in the secret", '|')
	var username_password_separator:String;
	@:editable("Writes 'username'->key_after_user->'password'->'enter'", 'tab', ['tab', 'enter'])
	var key_after_user:String;
	@:editable("Milliseconds to wait between username and password", 0)
	var user_pass_delay:UInt;
	@:editable("Cache gopass response in memory on initialization.", true)
	var cache_on_init:Bool;
	@:editable("Cache gopass response in memory when executed. This will be forced to true if 'cache_on_init' is true.", true)
	var cache_response:Bool;
}

@:name("gopass")
@:description("Get secrets from gopass application")
class Gopass extends IdeckiaAction {
	var actionLogin:ActionLogin;

	static inline var DEFAULT_SEPARATOR = '|';

	function createActionLogin(_props:Any) {
		try {
			var action = new ActionLogin();
			action.setup(_props, server);
			return action;
		} catch (e:Any) {
			server.dialog.error('Gopass action',
				'Could not load the action "log-in" from actions folder. You can download it from https://github.com/ideckia/action_log-in/releases/tag/v1.0.0');

			return null;
		}
	}

	override public function init(initialState:ItemState):js.lib.Promise<ItemState> {
		if (props.username_password_separator == '')
			props.username_password_separator = DEFAULT_SEPARATOR;
		if (props.cache_on_init) {
			props.cache_response = true;
			loadSecret().then(userpass -> {
				switch userpass {
					case Some(v):
						server.log.debug('Got [${props.secret_name}] secret correctly.');
						actionLogin = createActionLogin({
							username: v.username,
							password: v.password,
							key_after_user: props.key_after_user,
							user_pass_delay: props.user_pass_delay,
						});
						actionLogin.init(initialState);
					case None:
						server.log.error('Cannot get [${props.secret_name}] secret.');
				}
			});
		}

		return super.init(initialState);
	}

	public function execute(currentState:ItemState):js.lib.Promise<ItemState> {
		return new js.lib.Promise((resolve, reject) -> {
			if (actionLogin != null && props.cache_response)
				resolve(currentState);

			loadSecret().then(userpass -> {
				switch userpass {
					case Some(v):
						server.log.debug('Got [${props.secret_name}] secret correctly.');
						actionLogin = createActionLogin({
							username: v.username,
							password: v.password,
							key_after_user: props.key_after_user,
							user_pass_delay: props.user_pass_delay,
						});
						actionLogin.init(currentState);
						actionLogin.execute(currentState).then(s -> resolve(s)).catchError(e -> reject(e));
					case None:
						server.log.error('Cannot get [${props.secret_name}] secret.');
				}
			});
		});
	}

	override public function onLongPress(currentState:ItemState):js.lib.Promise<ItemState> {
		actionLogin = null;
		return execute(currentState);
	}

	function loadSecret():js.lib.Promise<Option<UserPass>> {
		return new Promise<Option<UserPass>>((resolve, reject) -> {
			var cp = js.node.ChildProcess.spawn('gopass', ['show', '-o', props.secret_name], {shell: true});

			var data = '';
			var error = '';
			cp.stdout.on('data', d -> data += d);
			cp.stdout.on('end', d -> {
				var cleanData = cleanResponse(data);
				if (error != '' || cleanData.length == 0)
					resolve(None);
				else {
					var cleanArray = cleanData.split(props.username_password_separator);
					var userPass = if (cleanArray.length == 1) {
						{username: '', password: cleanArray[0]};
					} else {
						{username: cleanArray[0], password: cleanArray[1]}
					};

					resolve(Some(userPass));
				}
			});
			cp.stderr.on('data', e -> error += e);
			cp.stderr.on('end', e -> {
				if (error != '')
					reject(error);
			});

			cp.on('error', (error) -> {
				reject(error);
			});
		});
	}

	inline function cleanResponse(response:String) {
		return ~/\r?\n/g.replace(response, '');
	}
}

typedef UserPass = {
	var username:String;
	var password:String;
}
