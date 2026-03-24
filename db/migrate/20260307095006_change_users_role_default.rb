class ChangeUsersRoleDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :users, :role, from: "org_admin", to: "org_member"
  end
end
