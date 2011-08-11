class AddCommentToAddress < ActiveRecord::Migration
  def self.up
    add_column :addresses, :comment, :string
  end

  def self.down
    remove_column :addresses, :comment
  end
end
