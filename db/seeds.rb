# encoding: utf-8
# Autogenerated by the db:seed:dump task
# Do not hesitate to tweak this to your needs

puts "Seeding database..."

puts "Creating users..."
marri = User.create!(username: 'Marri', password: 'nikari', email: "dummy1@example.com", default_editor: 'html', unread_opened: true,
                    role_id: Permissible::ADMIN, default_view: 'list', layout: 'starrylight', moiety_name: 'Red', moiety: 'AA0000', hide_warnings: true,
                    ignore_unread_daily_report: true, visible_unread: true)
alicorn = User.create!(username: 'Alicorn', password: 'alicorn', email: "dummy2@example.com")
kappa = User.create!(username: 'Kappa', password: 'pythbox', email: "dummy3@example.com")
aestrix = User.create!(username: 'Aestrix', password: 'aestrix', email: "dummy4@example.com")
throne = User.create!(username: 'Throne3d', password: 'throne3d', email: "dummy5@example.com", role_id: Permissible::MOD)
teceler = User.create!(username: 'Teceler', password: 'teceler', email: "dummy6@example.com", role_id: Permissible::MOD, default_editor: 'html',
                    layout: 'starrydark', ignore_unread_daily_report: true)

User.update_all(tos_version: 20181109)

puts "Creating avatars..."
Icon.create!([
  { user_id: 1, url: "https://pbs.twimg.com/profile_images/482603626/avatar.png", keyword: "avatar" },
  { user_id: 2, url: "https://33.media.tumblr.com/avatar_ddf517a261d8_64.png", keyword: "avatar" },
  { user_id: 3, url: "https://i.imgur.com/OJSBRcp.jpg", keyword: "avatar" },
  { user_id: 5, url: "https://i.imgur.com/7aXnrK1.jpg", keyword: "avatar" },
  { user_id: 6, url: "https://i.imgur.com/WA1r2Fu.png", keyword: "avatar" },
])
marri.update!(avatar_id: 1)
alicorn.update!(avatar_id: 2)
kappa.update!(avatar_id: 3)
throne.update!(avatar_id: 4)
teceler.update!(avatar_id: 5)

puts "Creating continuities..."
Board.create!([
  { name: 'Effulgence', creator: alicorn, coauthors: [kappa] },
  { name: 'Witchlight', creator: alicorn, coauthors: [marri] },
  { name: 'Sandboxes', creator: marri, pinned: true },
  { name: 'Site testing', creator: marri },
  { name: 'Pixiethreads', creator: kappa, coauthors: [aestrix] },
  { name: 'Incandescence', creator: alicorn, coauthors: [aestrix] },
])

puts "Creating sections..."
BoardSection.create!([
  { board_id: 1, name: "make a wish", status: 1, section_order: 0 },
  { board_id: 1, name: "hexes", status: 1, section_order: 1 },
  { board_id: 1, name: "parable of the talents", status: 1, section_order: 2 },
  { board_id: 1, name: "golden opportunity", status: 0, section_order: 3 },
])

puts "Creating icons..."
load Rails.root.join('db', 'seeds', 'icon.rb')

puts "Creating templates..."
load Rails.root.join('db', 'seeds', 'character.rb')

puts "Creating galleries..."
load Rails.root.join('db', 'seeds', 'gallery.rb')

puts "Creating posts..."
load Rails.root.join('db', 'seeds', 'post.rb')

puts "Creating replies..."
load Rails.root.join('db', 'seeds', 'reply.rb')

puts "Creating tags..."
load Rails.root.join('db', 'seeds', 'tag.rb')

puts "Creating audits..."
load Rails.root.join('db', 'seeds', 'audit.rb')

puts "Creating messages..."
Message.create!([
  { sender_id: 0, recipient_id: 3, subject: "Post import succeeded",
    message: "Your post was successfully imported! <a href='https://localhost:3000/posts/86'>View it here</a>.", unread: false },
  { sender_id: 1, recipient_id: 3, subject: "Test Message", message: "Sample text" },
  { sender_id: 3, recipient_id: 1, parent_id: 2, message: "Sample reply", unread: false },
  { sender_id: 1, recipient_id: 3, parent_id: 2, message: "Sample reply 2" },
])
