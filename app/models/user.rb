class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable

  belongs_to :organisation, optional: true

  ROLES = %w[super_admin org_admin org_member].freeze

  validates :name, presence: true
  validates :role, inclusion: { in: ROLES }
  validates :organisation, presence: true, unless: -> { role == "super_admin" }

  def super_admin?
    role == "super_admin"
  end

  def org_admin?
    role == "org_admin"
  end

  def org_member?
    role == "org_member"
  end
end
