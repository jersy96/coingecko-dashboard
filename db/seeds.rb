User.find_or_create_by!(email: "viewer@example.com") { |user| user.role = :viewer }
User.find_or_create_by!(email: "trader@example.com") { |user| user.role = :trader }
User.find_or_create_by!(email: "admin@example.com") { |user| user.role = :admin }
