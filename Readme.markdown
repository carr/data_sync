Data sync
=======

Rails plugin for syncing production database and files to local development server.


Install
=======

To install, just add Data sync to your `vendor/plugins` directory:

    script/plugin install git://github.com/carr/data_sync.git

Usage
=====

For pulling the database of the remote server

    rake db:pull

For pulling the database and the files of the remote server

    rake data:pull

TODO
====

* Prompt ("All files will be overwritten..")
* compression of .sql files
* database and files push
* change usage to "push:files", "push:db", "push:data", "pull:files", "pull:db", "pull:files"
* refactor rake task, duplicate code
