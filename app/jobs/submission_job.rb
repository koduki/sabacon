class SubmissionJob < ApplicationJob
  queue_as :default
  #sidekiq_options :retry => false

  def perform(submission)
    p "Process #{submission}"
    SubmissionRunner.new.run submission
  end
end
