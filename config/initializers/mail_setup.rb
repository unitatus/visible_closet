
ActionMailer::Base.smtp_settings = {
  :address              => "smtpout.secureserver.net",
  :port                 => 80,
  :domain               => "www.thevisiblecloset.com",
  :user_name            => "dave@thevisiblecloset.com",
  :password             => "ATIB4aPG",
  :authentication       => "plain"
} if Rails.env.development?


ActionMailer::Base.default_url_options[:host] = "localhost:3000" if Rails.env.development?
ActionMailer::Base.default_url_options[:host] = "localhost:3000" if Rails.env.test?
ActionMailer::Base.default_url_options[:host] = "evening-sky-543.heroku.com" if Rails.env.production?

#Mail.register_interceptor(DevelopmentMailInterceptor) if Rails.env.development?
