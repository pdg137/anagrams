require 'rails_helper'

RSpec.describe "games/index", type: :view do
  before(:each) do
    assign(:games, [
      Game.create!(),
      Game.create!()
    ])
  end

  it "renders a list of games" do
    render
    cell_selector = 'div>p'
  end
end
