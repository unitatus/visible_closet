class GenericTransaction
  attr_accessor :core_transaction
  
  def GenericTransaction.new(core_transaction)
    generic_transaction = super()
    generic_transaction.core_transaction = core_transaction
    
    return generic_transaction
  end
  
  def GenericTransaction.find_all_by_user_id(user_id)
    payment_transactions = PaymentTransaction.find_all_by_user_id(user_id)
    charges = Charge.find_all_by_user_id(user_id)
    
    return_array = Array.new()
    
    payment_transactions.each do |transaction|
      return_array << GenericTransaction.new(transaction)
    end
    
    charges.each do |charge|
      return_array << GenericTransaction.new(charge)
    end
    
    return return_array
  end
  
  def id
    core_transaction.id
  end
  
  def debit
    if core_transaction.is_a?(Charge)
      return core_transaction.total_in_cents/100.0
    else
      return nil
    end
  end
  
  def credit
    if core_transaction.is_a?(PaymentTransaction)
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
    else
      return "payment"
    end
  end
end