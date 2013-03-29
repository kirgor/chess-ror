Chess::Application.routes.draw do
    root :to => 'game#menu'
    get 'game', :to => 'game#index'
    get 'join', :to => 'game#join'
    post 'new', :to => 'game#new'
    get 'move/:id', :to => 'game#current_move'
    post 'move/:id', :to => 'game#move'
    post 'subscribe/:id', :to => 'game#subscribe'
    get 'board/:id', :to => 'game#board'
end
