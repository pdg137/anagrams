require 'rails_helper'

RSpec.describe "games/show", type: :view do
  before do
    assign(:game, Game.create!(log: 'ABCD'))
  end

  it "renders the destroy button" do
    render
    expect(rendered).to include("Destroy this game")
  end
end
