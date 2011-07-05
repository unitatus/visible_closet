
ActionMailer::Base.smtp_settings = {
  :address              => "smtp.gmail.com",
  :port                 => 587,
  :domain               => "gmail.com",
  :user_name            => "suggenda",
  :password             => "outobahn",
  :authentication       => "plain",
  :enable_starttls_auto => true
#} if Rails.env.development?
} # same for production?


ActionMailer::Base.default_url_options[:host] = "localhost:3000" if Rails.env.development?
ActionMailer::Base.default_url_options[:host] = "localhost:3000" if Rails.env.test?
ActionMailer::Base.default_url_options[:host] = "evening-sky-543.heroku.com" if Rails.env.production?

#Mail.register_interceptor(DevelopmentMailInterceptor) if Rails.env.development?
