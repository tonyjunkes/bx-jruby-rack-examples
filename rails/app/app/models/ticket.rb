class Ticket < ApplicationRecord
    STATUSES = %w[open in_progress resolved].freeze
    PRIORITIES = %w[low normal high urgent].freeze

    belongs_to :customer
    belongs_to :assignee, class_name: 'Agent', optional: true
    has_many :comments, -> { order(:created_at, :id) }
    validates :customer, presence: true
    validates :assignee, presence: true, if: -> { assignee_id.present? }
    validates :title, presence: true, length: { maximum: 160 }
    validates :description, presence: true, length: { maximum: 10000 }
    validates :status, inclusion: { in: STATUSES }
    validates :priority, inclusion: { in: PRIORITIES }

    # Filters are shared by the list and pagination count, using bound SQL values.
    def self.filtered(filters)
        scope = includes(:customer, :assignee)
        query = filters['q'].to_s.strip.first(200)
        unless query.empty?
            term = "%#{sanitize_sql_like(query, '!')}%"
            scope = scope.where("title LIKE ? ESCAPE '!' OR description LIKE ? ESCAPE '!'", term, term)
        end
        scope = scope.where(status: filters['status']) if STATUSES.include?(filters['status'])
        scope = scope.where.not(status: 'resolved') if filters['status'] == 'active'
        scope = scope.where(priority: filters['priority']) if PRIORITIES.include?(filters['priority'])
        if filters['assignee'] == 'unassigned'
            scope = scope.where(assignee_id: nil)
        elsif filters['assignee'].to_s.match?(/\A[1-9]\d*\z/)
            scope = scope.where(assignee_id: filters['assignee'].to_i)
        end
        scope.order(updated_at: :desc, id: :desc)
    end
end
