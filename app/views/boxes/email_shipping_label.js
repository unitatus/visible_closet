var box_link = document.getElementById('box_<%= @box.id %>_label_link');

box_link.dataset.confirm = "This box's label was emailed to you on <%= @box.last_shipment_to_tvc.last_label_emailed.strftime '%m/%d/%Y' %>; click ok to cancel this label and issue another one, or cancel to do nothing.";
alert('Your shipping label has been emailed to you.');