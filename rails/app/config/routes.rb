Rails.application.routes.draw do
    root 'desk#dashboard'
    get '/tickets', to: 'tickets#index'
    get '/tickets/new', to: 'tickets#new'
    post '/tickets', to: 'tickets#create'
    get '/tickets/:id', to: 'tickets#show', constraints: { id: /\d+/ }
    get '/tickets/:id/edit', to: 'tickets#edit', constraints: { id: /\d+/ }
    post '/tickets/:id', to: 'tickets#update', constraints: { id: /\d+/ }
    post '/tickets/:id/comments', to: 'comments#create', constraints: { id: /\d+/ }
    get '/customers', to: 'customers#index'
    get '/customers/new', to: 'customers#new'
    post '/customers', to: 'customers#create'
    get '/customers/:id', to: 'customers#show', constraints: { id: /\d+/ }
    get '/customers/:id/edit', to: 'customers#edit', constraints: { id: /\d+/ }
    post '/customers/:id', to: 'customers#update', constraints: { id: /\d+/ }
    post '/identity', to: 'desk#identity'
    match '*path', to: 'desk#not_found', via: :all
end
