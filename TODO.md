# DreamGuild.eu TODO


### New Features

* Add who is online in mumble.
* Add player of the week (based on XP contribution to guild for the week).
* Add remove/edit function to comments for it's owner and admins.
* Show comment tab after a comment is posted.
* Make nav items visible for everyone. I don't think this is a good idea.
* Add FB Fan page link to somewhere. It must be only visible to strangers.


### New Features for Admins

* Add rank number to text editor.
* Add option to update roster.


### Under the hood

* After an application accepted, nothing is happening. Something must happen.
  Possible route:
    App -> Accept -> Update roster -> Assign Acc -> Select his main
  I need to get 'accepted and not in guild yet' accounts from user table
  and show it in assign method.
* Fix multiline texts in application fields and comments.
* Battle.net doesn't provide rendered avatars and/or backgrounds for some
  characters. (Probably Level 60- characters). Need to add 'placeholder'
  avatar for this characters.
* Add crontab's to update roster automatically.
* Check app status for votes in controller.
* Check password lenght on register.
* Use over[1] to check authentication and refactor code repeats
  in Application.pm
* Post new applications to facebook.
* Add facebook fields to configuration example.
* Add documentation to configuration example.



1: http://mojolicio.us/perldoc/Mojolicious/Routes/Route#over
