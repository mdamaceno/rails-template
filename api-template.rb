gem_group :development do
  gem "brakeman", require: false
  gem "bundler-audit"
  gem "rails_best_practices"
  gem "solargraph", require: false
  gem "solargraph-rails", require: false
end

gem_group :test do
  gem "simplecov", require: false
end

gem_group :development, :test do
  gem "amazing_print"
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "pry"
  gem "pry-rails"
  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem "standard"
  gem "standard-rails"
end

gem "devise_token_auth", git: "https://github.com/lynndylanhurley/devise_token_auth"

environment "config.generators { |g| g.orm :active_record, primary_key_type: :uuid }"

rakefile("brakeman.rake") do
  <<-TASK
  if Gem::Specification.find_all_by_name("brakeman").present?
    namespace :brakeman do
      desc "Check your code with Brakeman"
      task check: :environment do
        require "brakeman"
        r = Brakeman.run app_path: ".", print_report: true, pager: false
        exit Brakeman::Warnings_Found_Exit_Code unless r.filtered_warnings.empty?
      end
    end
  end
  TASK
end

rakefile("bundler_audit.rake") do
  <<-TASK
  if Gem::Specification.find_all_by_name("bundler-audit").present?
    require "bundler/audit/task"
    Bundler::Audit::Task.new
  end
  TASK
end

rakefile("rails_best_practices.rake") do
  <<-TASK
  task rails_best_practices: :environment do
    sh "rails_best_practices"
  end
  TASK
end

rakefile("rubocop.rake") do
  <<-TASK
  if Gem::Specification.find_all_by_name("rubocop").present?
    require "rubocop/rake_task"
    RuboCop::RakeTask.new(:rubocop) do |task|
      task.fail_on_error = false
      task.options = ["--auto-correct-all"]
    end
  end
  TASK
end

file "Rakefile", <<~RAKE
  # Add your own tasks in files placed in lib/tasks ending in .rake,
  # for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

  require_relative "config/application"

  Rails.application.load_tasks

  task default: %i[
    rubocop
    test
    rails_best_practices
    brakeman:check
    bundle:audit
  ]
RAKE

file "config/initializers/devise_token_auth.rb", <<~CODE
  # frozen_string_literal: true

  DeviseTokenAuth.setup do |config|
    # By default the authorization headers will change after each request. The
    # client is responsible for keeping track of the changing tokens. Change
    # this to false to prevent the Authorization header from changing after
    # each request.
    # config.change_headers_on_each_request = true

    # By default, users will need to re-authenticate after 2 weeks. This setting
    # determines how long tokens will remain valid after they are issued.
    # config.token_lifespan = 2.weeks

    # Limiting the token_cost to just 4 in testing will increase the performance of
    # your test suite dramatically. The possible cost value is within range from 4
    # to 31. It is recommended to not use a value more than 10 in other environments.
    config.token_cost = Rails.env.test? ? 4 : 10

    # Sets the max number of concurrent devices per user, which is 10 by default.
    # After this limit is reached, the oldest tokens will be removed.
    # config.max_number_of_devices = 10

    # Sometimes it's necessary to make several requests to the API at the same
    # time. In this case, each request in the batch will need to share the same
    # auth token. This setting determines how far apart the requests can be while
    # still using the same auth token.
    # config.batch_request_buffer_throttle = 5.seconds

    # This route will be the prefix for all oauth2 redirect callbacks. For
    # example, using the default '/omniauth', the github oauth2 provider will
    # redirect successful authentications to '/omniauth/github/callback'
    # config.omniauth_prefix = "/omniauth"

    # By default sending current password is not needed for the password update.
    # Uncomment to enforce current_password param to be checked before all
    # attribute updates. Set it to :password if you want it to be checked only if
    # password is updated.
    # config.check_current_password_before_update = :attributes

    # By default we will use callbacks for single omniauth.
    # It depends on fields like email, provider and uid.
    # config.default_callbacks = true

    # Makes it possible to change the headers names
    # config.headers_names = {
    #   :'authorization' => 'Authorization',
    #   :'access-token' => 'access-token',
    #   :'client' => 'client',
    #   :'expiry' => 'expiry',
    #   :'uid' => 'uid',
    #   :'token-type' => 'token-type'
    # }

    # Makes it possible to use custom uid column
    # config.other_uid = "foo"

    # By default, only Bearer Token authentication is implemented out of the box.
    # If, however, you wish to integrate with legacy Devise authentication, you can
    # do so by enabling this flag. NOTE: This feature is highly experimental!
    # config.enable_standard_devise_support = false

    # By default DeviseTokenAuth will not send confirmation email, even when including
    # devise confirmable module. If you want to use devise confirmable module and
    # send email, set it to true. (This is a setting for compatibility)
    # config.send_confirmation_email = true
  end
CODE

file "config/routes.rb", <<~CODE
  Rails.application.routes.draw do
    mount_devise_token_auth_for "User", at: "auth"

    # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

    # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
    # Can be used by load balancers and uptime monitors to verify that the app is live.
    get "up" => "rails/health#show", :as => :rails_health_check

    # Defines the root path route ("/")
    # root "posts#index"
  end
CODE

file "app/models/user.rb", <<~CODE
  # frozen_string_literal: true

  class User < ApplicationRecord
    extend Devise::Models

    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
    devise :database_authenticatable, :registerable,
      :recoverable, :rememberable, :validatable

    include DeviseTokenAuth::Concerns::User
  end
CODE

file "config/database.yml", <<~CODE
  default: &default
    adapter: postgresql
    encoding: unicode
    username: postgres
    password: postgres
    host: localhost
    port: <%= ENV.fetch("POSTGRES_PORT") %>
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

  development:
    <<: *default
    database: #{ENV['APP_NAME']}_development

  test:
    <<: *default
    database: #{ENV['APP_NAME']}_test

  production:
    <<: *default
    database: #{ENV['APP_NAME']}_production
    username: #{ENV['APP_NAME']}
    password: <%= ENV["#{ENV['APP_NAME'].upcase}_DATABASE_PASSWORD"] %>
CODE

file "db/migrate/#{Time.now.strftime("%Y%m%d%H%M%S")}_devise_token_auth_create_users.rb", <<~CODE
  class DeviseTokenAuthCreateUsers < ActiveRecord::Migration[7.1]
    def change
      create_table(:users, id: :uuid) do |t|
        ## Required
        t.string :provider, null: false, default: "email"
        t.string :uid, null: false, default: ""

        ## Database authenticatable
        t.string :encrypted_password, null: false, default: ""

        ## Recoverable
        t.string :reset_password_token
        t.datetime :reset_password_sent_at
        t.boolean :allow_password_change, default: false

        ## Rememberable
        t.datetime :remember_created_at

        ## Confirmable
        t.string :confirmation_token
        t.datetime :confirmed_at
        t.datetime :confirmation_sent_at
        t.string :unconfirmed_email # Only if using reconfirmable

        ## Lockable
        # t.integer  :failed_attempts, :default => 0, :null => false # Only if lock strategy is :failed_attempts
        # t.string   :unlock_token # Only if unlock strategy is :email or :both
        # t.datetime :locked_at

        ## User Info
        t.string :name
        t.string :username
        t.string :email

        ## Tokens
        t.json :tokens

        t.timestamps
      end

      add_index :users, :email, unique: true
      add_index :users, :username, unique: true
      add_index :users, [:uid, :provider], unique: true
      add_index :users, :reset_password_token, unique: true
      add_index :users, :confirmation_token, unique: true
      # add_index :users, :unlock_token,         unique: true
    end
  end
CODE

file ".rubocop.yml", <<~CONFIG
  require:
    - standard
    - standard-custom
    - standard-performance
    - rubocop-performance

  inherit_gem:
    standard: config/base.yml
    standard-custom: config/base.yml
    standard-performance: config/base.yml
CONFIG

file "test/test_helper.rb", <<~CODE
  ENV["RAILS_ENV"] ||= "test"
  require_relative "../config/environment"
  require "rails/test_help"

  module ActiveSupport
    class TestCase
      # Run tests in parallel with specified workers
      parallelize(workers: :number_of_processors)

      # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
      # fixtures :all

      # FactoryBot
      include FactoryBot::Syntax::Methods

      # Add more helper methods to be used by all tests here...

      def assert_attribute_contains_error(object, attribute, error, message = nil)
        object.valid?
        errors = object.errors.select { |a| a.attribute == attribute }.map(&:type)
        assert_includes errors, error, message
      end
    end
  end
CODE

file "test/factories/users.rb", <<~CODE
  FactoryBot.define do
    factory :user, class: "User" do
      name { Faker::Name.name }
      username { Faker::Internet.username }
      email { Faker::Internet.email }
      password { "password" }
      password_confirmation { "password" }
    end
  end
CODE

file ".standard.yml", <<~CONFIG
  plugins:
    - standard-rails
CONFIG

file "local.Dockerfile", <<~DOCKER
  FROM ruby:3.2.2-slim

  RUN apt-get update -qq
  RUN apt-get install -y \
      build-essential \
      libpq-dev \
      nodejs \
      npm \
      git \
      shared-mime-info \
      nano

  ENV VISUAL=nano

  RUN npm i -g yarn

  ENV app /app

  RUN mkdir $app

  WORKDIR $app

  RUN gem install bundler

  COPY Gemfile /app/

  ENV BUNDLE_PATH /box
DOCKER

file "docker-compose.yml", <<~DOCKER
  version: '3.7'

  services:
    redis:
      image: redis:alpine
      container_name: #{ENV['APP_NAME']}-redis
      ports:
        - ${REDIS_PORT:-63791}:6379

    postgres:
      image: postgres:16-alpine
      container_name: #{ENV['APP_NAME']}-postgres
      ports:
        - ${POSTGRES_PORT:-54321}:5432
      environment:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: postgres
        POSTGRES_DB: #{ENV['APP_NAME']}_development
      volumes:
        - postgres:/var/lib/postgresql/data

  volumes:
    postgres:
DOCKER
