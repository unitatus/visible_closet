class GenericTransaction
  attr_accessor :core_transaction
  
  def GenericTransaction.new(core_transaction)
    generic_transaction = super()
    generic_transaction.core_transaction = core_transaction
    
    return generic_transaction
  end
  
  def GenericTransaction.find_all_by_user_id(user_id)
    credits = Credit.find_all_by_user_id(user_id)
    charges = Charge.find_all_by_user_id(user_id)
    
    return_array = Array.new()
    
    credits.each do |credit|
      return_array << GenericTransaction.new(credit)
    end
    
    charges.each do |charge|
      return_array << GenericTransaction.new(charge)
    end
    
    return return_array
  end
  
  def id
    core_transaction.id
  end
  
  def deletable?
    core_transaction.deletable?
  end
  
  def credit?
    core_transaction.is_a?(Credit)
  end
  
  def charge?
    core_transaction.is_a?(Charge)
  end
  
  def debit
    if core_transaction.is_a?(Charge)
      return core_transaction.total_in_cents/100.0
    else
      return nil
    end
  end
  
  def credit
    if core_transaction.is_a?(Credit)
      return core_transaction.amount
    else
      return nil
    end
  end
  
  def value
    if core_transaction.is_a?(Charge)
      return core_transaction.total_in_cents/100.0*-1
    else
      return core_transaction.amount
    end
  end
  
  def created_at
    return core_transaction.created_at
  end
  
  def type_en
    if core_transaction.is_a?(Charge)
      return "charge"
    elsif core_transaction.payment_transaction
      return "payment"
    else
      return "credit"
    end
  end
end