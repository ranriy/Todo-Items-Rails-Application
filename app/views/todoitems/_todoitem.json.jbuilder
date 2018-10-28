json.extract! todoitem, :id, :title, :due_date, :description, :completed, :created_at, :updated_at
json.url todoitem_url(todoitem, format: :json)
