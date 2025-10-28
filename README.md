# Kanboard on Railway

This repository provides a ready-to-deploy **Kanboard** instance on [Railway](https://railway.com/), using the official Docker image and PostgreSQL as the database.

**Kanboard** is a minimalist open-source project management tool based on the Kanban method — visual boards, swimlanes, automation, and plugin extensibility.

---

## 🚀 Deploy on Railway

Click below to deploy instantly:

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/kanboard?referralCode=1q5cCO&utm_medium=integration&utm_source=template&utm_campaign=generic)

---

## 🔧 Environment Variables

Only three variables are required:

```env
PLUGIN_INSTALLER="true"  # Enable plugin installation from the UI
KANBOARD_URL="https://${{RAILWAY_PUBLIC_DOMAIN}}"  # Public URL of your instance
DATABASE_URL="postgres://${{Postgres.PGUSER}}:${{Postgres.PGPASSWORD}}@${{Postgres.PGHOST}}:${{Postgres.PGPORT}}/${{Postgres.PGDATABASE}}"  # PostgreSQL connection string
```

Plugins installed from the interface are **automatically persisted** across restarts and redeployments.

---

## 🧑‍💼 Default Account

After deployment, log in with:

```
Username: admin
Password: admin
```

You can change this password anytime at:

```
/user/1/password
```

---

## 📝 Notes

- This setup uses the **official `kanboard/kanboard` image** — no forks.
- PostgreSQL is managed by Railway.
- Plugin persistence and installer support are included out of the box.

For full documentation, visit [https://docs.kanboard.org](https://docs.kanboard.org).
