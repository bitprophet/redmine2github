# Translation notes

## Issue

### Notes

* Can't set number explicitly :( so need to go in order and abort if we can't match things up correctly -- probably detect after done w/ an issue whether it got the right ID
* Can't set state when creating, so need a create-and-edit flow
* No concept of closing-as-dupe, closing-as-wontfix in GH, so probably use labels for that
* No concept of "submitter" on GH (except in pull requests, kinda) so put that in as a prefix/postfix to body text probably
* Assignee should be me always -- a few things are assigned to Morgan but that doesn't really mean anything serious ATM, we can rework how we want to use that on the GH side later.
* Priorities -- keep the "random access" ones we sometimes want lists of, mostly Wart/Quick, drop the rest since we can't sort by them.
* Original creation time will need to be prefixed/postfixed to body text, or discarded?


### Mapping

* `id` => have to set implicitly by going in order
* `tracker` => map to a label, 'feature' / 'bug' / 'support'
* `subject` => `title`
* `description` => `body`
* `category` => map to a label with similar name
    * Take this opportunity to remap bad or redundant categories, like UI vs CLI
* `status` => map to open/closed, *and* probably to a label too in some cases
* `assigned_to` => "bitprophet"
* `priority` => map some to labels, eg wart and quick, drop the rest
* `author` => note in body text
* `created_on` => note in body text (?)
* `updated_on` => ditto
hrm
