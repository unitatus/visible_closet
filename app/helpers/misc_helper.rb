module MiscHelper
  def MiscHelper.aggregate_transactions(transactions)
    running_total = 0.0
    
    transactions.each do |transaction|
      running_total += transaction.amount.to_f
    end
    
    return running_total
  end
end