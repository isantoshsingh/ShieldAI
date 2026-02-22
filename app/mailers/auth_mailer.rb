class AuthMailer < ApplicationMailer
  def magic_link(user, link)
    @user       = user
    @magic_link = link
    @login_url  = magic_login_url(token: link.token)

    mail(
      to:      user.email,
      subject: "Your ShieldAI login link"
    )
  end
end
