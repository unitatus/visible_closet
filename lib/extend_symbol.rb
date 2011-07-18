class Symbol
  def quoted_id
    # Since symbols always contain save characters (no backslash or apostrophe), it's
    # save to skip calling ActiveRecord::ConnectionAdapters::Quoting#quote_string here
    "'#{self.to_s}'"
  end
end
