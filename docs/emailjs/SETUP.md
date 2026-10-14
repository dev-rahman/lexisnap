# EmailJS setup for the in-app support form

The help screen sends two emails through [EmailJS](https://www.emailjs.com):
the support request to your inbox, and a copy to the user. No backend of your
own is needed. Until the values below are filled in, the form falls back to
opening the user's own mail app, so the app keeps working before setup.

You'll end up with five values for `.env`:

```
EMAILJS_SERVICE_ID=
EMAILJS_PUBLIC_KEY=
EMAILJS_PRIVATE_KEY=
EMAILJS_TEMPLATE_SUPPORT=
EMAILJS_TEMPLATE_RECEIPT=
```

## 1. Create an account

Sign up at emailjs.com (the free tier allows 200 emails/month). Each support
request sends two emails, so that's ~100 requests/month on free.

## 2. Add an email service

- Dashboard → **Email Services** → **Add New Service**.
- Pick the mailbox the emails are sent *from* (Gmail, Outlook, or a custom
  SMTP). For `support@lexisnap.app`, use your provider's SMTP, or connect a
  Gmail/Workspace account and verify it.
- After connecting, copy the **Service ID** (looks like `service_xxxxxxx`).
  → `EMAILJS_SERVICE_ID`

## 3. Create the two templates

Dashboard → **Email Templates** → **Create New Template**, twice.

### Template A - support ticket (to your inbox)

- Open the **Content** editor, switch to the code/HTML view, and paste
  `support_ticket.html` from this folder.
- In the template's **Settings**, set:
  - **To Email**: `{{to_email}}`
  - **From Name**: `LexiSnap support`
  - **From Email**: use the service's default (your connected address)
  - **Reply To**: `{{reply_to}}`  (this is the user's email, so Reply answers them)
  - **Subject**: `New support message from {{user_name}}`
- Save. Copy the **Template ID** (`template_xxxxxxx`).
  → `EMAILJS_TEMPLATE_SUPPORT`

### Template B - user receipt (the copy to the user)

- Paste `user_receipt.html` into the Content code view.
- Settings:
  - **To Email**: `{{to_email}}`
  - **From Name**: `LexiSnap`
  - **Reply To**: `{{reply_to}}`  (this is your support inbox)
  - **Subject**: `We got your message`
- Save. Copy the **Template ID**.
  → `EMAILJS_TEMPLATE_RECEIPT`

The app fills these template variables: `user_name`, `user_email`, `message`,
`platform`, `submitted_at`, `to_email`, `reply_to`. You don't have to use all
of them, but don't rename the ones the templates reference.

## 4. Get your keys

- **Public key**: Account → **General** → *Public Key*. → `EMAILJS_PUBLIC_KEY`
- **Private key**: Account → **Security** → *Private Key*. → `EMAILJS_PRIVATE_KEY`

## 5. Allow calls from the app (required)

EmailJS blocks API calls from non-browser apps by default, which makes the app
get `403: API calls are disabled for non-browser applications`. To fix it:

- Account → **Security** → enable **"Allow EmailJS API for non-browser
  applications"**. Save. This is the switch that fixes the 403.

Optionally, in the same place you can turn on **"Use Private Key"** auth; the
app already sends the private key when `EMAILJS_PRIVATE_KEY` is set, so it keeps
working with that on. If you don't use it, `EMAILJS_PRIVATE_KEY` can stay empty.

Both the public and private keys ship inside the app and can be extracted, so
they aren't true secrets here. EmailJS's own rate and quota limits are the real
guard - set a monthly quota and a per-period rate limit in Account → Security so
a leaked key can't be abused past your plan.

## 6. Fill in `.env`

Copy the five values into your `.env` (never commit it). Example:

```
EMAILJS_SERVICE_ID=service_ab12cde
EMAILJS_PUBLIC_KEY=AbCdEf0123456789
EMAILJS_PRIVATE_KEY=XyZ9876543210abcd
EMAILJS_TEMPLATE_SUPPORT=template_support1
EMAILJS_TEMPLATE_RECEIPT=template_receipt1
```

## 7. Test

- Run the app, sign in, open **Profile → Help & support**, type a message, and
  send. You should see "Message sent", a ticket in your support inbox, and a
  copy in the signed-in user's inbox.
- In EmailJS, **Dashboard → Email History** shows every send and any failures.

## Troubleshooting

- **403 "API calls are disabled for non-browser applications"**: the private
  key isn't set, or the account protection is on. Set `EMAILJS_PRIVATE_KEY`.
- **422 with a variable name**: a `{{variable}}` in the template has no match;
  check the names against step 3.
- **Nothing arrives but no error**: check the spam folder and EmailJS Email
  History; confirm the connected service address is verified.
- **Form opens the mail app instead of sending**: one of the five values is
  empty, or the user has no email on their account.
