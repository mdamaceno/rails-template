# Rails Template

A template for creating a new Rails app with some gems and configurations.

This template sets configuration for PostreSQL database, Devise for authentication and Docker files.

## How to use

```shell
APP_NAME=yourappname rails new yourappname --api -d postgresql -m ./api-template.rb -f
```

or

```shell
APP_NAME=yourappname rails new yourappname --api -d postgresql -m https://raw.githubusercontent.com/mdamaceno/rails-template/main/api-template.rb -f
```
