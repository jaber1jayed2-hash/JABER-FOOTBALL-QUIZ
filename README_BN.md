# JABER FOOTBALL QUIZ — প্রাথমিক Flutter প্রজেক্ট

## এখন কী আছে
- কালো ও সবুজ থিম
- বাংলা Home, Quiz, Live Football ও Profile পেজ
- আপনার নির্বাচিত ৮টি কুইজ মোডের তালিকা
- লাইভ স্কোর/ফিক্সচার/লিগ টেবিল/ফলাফলের placeholder
- Supabase-এর প্রাথমিক ডেটাবেস schema

## এখনো কী চালু হয়নি
এই প্রাথমিক সংস্করণে বাস্তব Registration/Login, অনলাইন leaderboard, 1v1, লাইভ ফুটবল ডেটা, push notification, ছবি-ভিত্তিক প্রশ্ন ও Admin Panel এখনো সংযুক্ত নয়। এগুলো পরবর্তী ধাপে backend, API key, database policies এবং বাস্তব প্রশ্ন/ছবির ডেটা দিয়ে যুক্ত করতে হবে।

## Flutter চালানোর জন্য
Flutter SDK ও Android build tools-সহ কম্পিউটার বা cloud build service প্রয়োজন।
1. Flutter SDK ইনস্টল করুন।
2. এই ফোল্ডারে `flutter pub get` চালান।
3. `flutter run` দিয়ে পরীক্ষা করুন।
4. APK বানাতে `flutter build apk --release` চালান।

## Android ফোন দিয়ে কাজ
শুধু ফোন থাকলে কোড দেখা/সম্পাদনা করা সম্ভব, কিন্তু Flutter APK build সাধারণত ফোনে সরাসরি করা কঠিন। Cloud development/build service ব্যবহার করা যেতে পারে। কোনো অচেনা সাইটে পাসওয়ার্ড বা API secret দেবেন না।

## লাইভ স্কোর নিরাপত্তা
Football API key Flutter অ্যাপের ভিতরে রাখবেন না। নিজের backend দিয়ে API কল করাবেন, যাতে key গোপন থাকে এবং request limit নিয়ন্ত্রণ করা যায়।

## পরবর্তী ধাপ
1. Supabase project তৈরি ও schema review।
2. Email/password authentication এবং profile creation।
3. বাস্তব quiz question bank ও scoring।
4. Football API নির্বাচন ও backend proxy।
5. Live scores, fixtures, standings, match details ও results।
6. Leaderboard, friends, 1v1 ও tournaments।
7. Admin dashboard, notification এবং release testing।
