class CsvExportMailer < ApplicationMailer
  def report(user, csv_string, filename, start_date, end_date)
    attachments[filename] = { mime_type: "text/csv", content: csv_string }
    mail(
      to: user.email,
      subject: "ShieldAI Report: #{start_date} to #{end_date}"
    )
  end
end
