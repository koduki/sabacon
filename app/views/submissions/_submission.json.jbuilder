json.extract! submission, :id, :problem, :repos_url, :tag, :created_at, :updated_at
json.url submission_url(submission, format: :json)