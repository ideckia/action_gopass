# Action for [ideckia](https://ideckia.github.io/): gopass

## Description

Get secrets from [gopass](https://www.gopass.pw/) application. This action will expect that the username and the password are separated by the character defined in the `username_password_separator` propertye (`|` by default -> e.g. `username|password`).

Action ['action_log-in'](http://github.com/ideckia/action_log-in) is required.

When the action is initialized, it will get the secret content and will keep it in memory. If the secret changes, the action will reload the secret with a long press.

## Properties

| Name | Type | Description | Shared | Default | Possible values |
| ----- |----- | ----- | ----- | ----- | ----- |
| secret_name | String | The name of the secret to retrieve | false | null | null |
| username_password_separator | String | The separator between username and password stored in the secret | false | "|" | null |
| key_after_user | String | Writes 'username'->key_after_user->'password'->'enter' | false | 'tab' | [tab,enter] |
| user_pass_delay | UInt | Milliseconds to wait between username and password | false | 0 | null |

## On single click

Writes the username and the password from the secret of gopass.

## On long press

Reload the secret value.

## Test the action

There is a script called `test_action.js` to test the new action. Set the `props` variable in the script with the properties you want and run this command:

```
node test_action.js
```

## Example in layout file

```json
{
    "state": {
        "text": "gopass action example",
        "actions": [
            {
                "name": "gopass",
                "props": {
                    "secret_name": "my_gopass_secret",
                    "key_after_user": "tab",
                    "user_pass_delay": 0
                }
            }
        ]
    }
}
```