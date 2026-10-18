# Only demo:prepare on a new database, or an explicit reset, loads these records.
ApplicationRecord.transaction do
    agents = ['Maya Chen', 'Jordan Ellis', 'Sam Rivera', 'Priya Shah', 'Alex Morgan'].map do |name|
        Agent.create!(name: name)
    end
    customers = [
        ['Nora Bell', 'Northline Studio', 'nora@northline.example'],
        ['Theo Grant', 'Harbor Foods', 'theo@harbor.example'],
        ['Amara Okafor', 'Greenway Health', 'amara@greenway.example'],
        ['Leo Park', 'Cedar Library', 'leo@cedar.example'],
        ['Isabel Costa', 'Summit Cycles', 'isabel@summit.example'],
        ['Owen Reed', 'Brightside School', 'owen@brightside.example'],
        ['Zara Patel', 'Atlas Workshop', 'zara@atlas.example'],
        ['Finn Brooks', 'Riverbend Market', 'finn@riverbend.example']
    ].map { |name, company, email| Customer.create!(name: name, company: company, email: email) }
    subjects = [
        'Invoice export leaves out purchase order numbers', 'New team member cannot access reports',
        'Delivery notification sent twice', 'Update billing contact for next quarter',
        'Dashboard totals differ from monthly report', 'Search does not find archived projects',
        'Printer connection drops at the front desk', 'Add a second location to our account',
        'Weekly digest arrives in the wrong time zone', 'Import customer list from our old system',
        'Help configuring approval limits', 'Receipt logo looks stretched on mobile',
        'Restore a project closed by mistake', 'Order confirmation is missing an item',
        'Set up read-only access for the finance team', 'Payment link expires before checkout',
        'Change the default shipping address', 'Calendar export shows duplicate entries',
        'Bulk update product categories', 'Report attachment cannot be opened',
        'Notification preferences are not saved', 'Account owner is leaving the company',
        'Inventory sync has stopped updating', 'Prepare a usage report for our review',
        'Labels are cut off on printed invoices', 'Add tax information to the receipt',
        'Project list loads slowly after filtering', 'Reconnect our email integration',
        'Need a copy of last year’s statements', 'Confirm the steps for our branch rollout'
    ]
    subjects.each_with_index do |title, i|
        ticket = Ticket.create!(
            customer: customers[i % customers.length], assignee: i % 4 == 0 ? nil : agents[i % agents.length],
            title: title, description: "Our team needs help with this issue. It affects our daily work at #{customers[i % 8].company}. Please review the current settings and let us know the next steps.",
            priority: Ticket::PRIORITIES[i % 4], status: Ticket::STATUSES[i % 3],
            created_at: Time.utc(2026, 10, 1) + i * 18000, updated_at: Time.utc(2026, 10, 2) + i * 18000
        )
        Comment.create!(ticket: ticket, agent: agents[i % 5], body: 'Reviewed the request and confirmed the details with the customer.', created_at: ticket.created_at + 600)
        if i.even?
            Comment.create!(ticket: ticket, agent: agents[(i + 1) % 5], body: 'The next step is documented. We will follow up after the customer has tried it.', created_at: ticket.created_at + 1200)
        end
    end
end
puts 'Seeded 5 agents, 8 customers, 30 tickets and 45 comments.'
