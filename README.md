<p align="center">
  <img src="https://i.ibb.co/6Rn265Br/free-icon-gold-coin-17307730.png" width="88" alt="Casha logo" />
</p>

<h1 align="center">Casha</h1>

<p align="center">
  A personal finance tracker that doesn't get in your way.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.11+-02569B?logo=flutter" />
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey" />
</p>

---

Most finance apps make you feel like you're filing taxes. Casha doesn't.
It's built around one idea: tracking your money should take seconds, not minutes. Clean interface, zero clutter, everything exactly where you'd expect it.

---

## What it does

Casha gives you a real-time picture of your finances without overwhelming you with features you'll never use. Add a transaction in two taps, see your balance update instantly, know exactly how far into your monthly budget you are — all from a single screen.

It's not trying to be a spreadsheet. It's trying to be the app you actually open.

---

## ✦ Features

**Balance Card**
The centerpiece of the dashboard. Your total balance, rendered on a customizable gradient card with a gyroscope-powered 3D tilt effect. Long-press to edit the gradient colors and type — linear, radial, sweep, or solid.

**Income & Expense Tracking**
Every transaction gets a category, an icon, an optional note, and a date. The list is instantly searchable and filterable by type. Nothing is buried.

**Category Breakdown**
A dedicated screen with pie and bar charts showing exactly where your money comes from and where it goes. Switch between expenses and income with a single tap.

**Monthly Budget**
Set a spending limit and watch a progress bar fill up in real time. Goes red when you're over — politely, not aggressively.

**Multi-currency Support**
USD, EUR, BYN, RUB — pick your primary currency in settings. Exchange rates are fetched automatically.

**Biometric Lock**
Optional fingerprint protection on launch. One toggle in settings, zero friction in daily use.

**Dark & Light Theme**
Follows your system theme automatically. Both themes are fully designed — not just inverted colors.

**Localization**
English and Russian, switchable in settings. Date formats, month names, category labels — everything adapts.

**Amount Formatting**
Choose between compact (1.2K) or full number display depending on how you think about money.

---

## 📱 Screenshots

<table>
  <tr>
    <td><img src="https://i.ibb.co/Fq06nxKM/screenshot.png" width="180" /></td>
    <td><img src="https://i.ibb.co/tPk9GVsn/flutter-01.png" width="180" /></td>
    <td><img src="https://i.ibb.co/DP0LBnK4/flutter-03.png" width="180" /></td>
    <td><img src="https://i.ibb.co/xtQ8MQNL/flutter-02.png" width="180" /></td>
  </tr>
</table>

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3 |
| State management | Riverpod |
| Navigation | go_router |
| Charts | fl_chart |
| Storage | shared_preferences + SQLite |
| Fonts | Google Fonts (Poppins + Nunito) |
| Sensors | sensors_plus |
| Auth | local_auth |

---

## 🚀 Getting Started

**Prerequisites**
- Flutter `^3.11.1`
- Android SDK (min API 21)
- JDK 17+

**Clone & run**

```console
git clone https://github.com/koloideal/casha.git
cd casha
flutter pub get
flutter run
