import 'dart:ui';
// const kBaseUrl = 'http://192.168.137.8:8000/api';
// const kBaseUrl = 'https://88c9-178-253-95-112.ngrok-free.app/api';

const kBaseUrl = 'http://10.0.2.2:8000/api';
// const kBaseUrl = 'https://bb6b-89-38-99-102.ngrok-free.app/api';
// const kBaseUrlAsset = 'https://06f4-145-249-67-8.ngrok-free.app';
//  const kBaseUrl = 'http://192.168.2.108:8000/api';
//const kBaseUrl = 'http://192.168.102.162:8000/api';
final kBaseUrlAsset = '${kBaseUrl.split('/api').first}/storage';
//const kBaseUrlAsset= 'http://127.0.0.1:8000';
const kSignIn = 'Login';
const kAppColor = Color(0xFF17505E);
// Color(0xFF17505E)
// Color(0xFF17505E)
// Color(0xFF17505E)
// Color(0xFF17505E)
// Color(0xFF17505E);

//const kAppColor = Color(0xff3fbbc0);
// const kAppColor = Color.fromARGB(255, 3, 228, 142);
const kSignUp = 'SighUp';
const kArabic = 'ar';
const kEnglish = 'en';
const kCommentChannelName = 'comment reply';
const kCommentGroupName = 'comment reply';
//const kVideoState = 'VideoState';
const kUser = 'User';
const kFileState = 'FileState';
const kVideo = 'Video';
const kQuestion = 'Question';
const kBlank = 'Blank';
const kMatchItem = 'MatchItem';
const kOption = 'Option';
const kCustomTime = 'CustomTime';
const kFieldRequests = 'FieldRequests';
List<String> boxNames = [
  kFileState,
  kVideo,
  kQuestion,
  kBlank,
  kMatchItem,
  kOption,
  kCustomTime,
  kFieldRequests,
];
const List<String> says = [
  "المعرفة تنمي القوة...",
  "التحصيل العلمي يفتح أفق النجاح...",
  "العقل يتسع للمعرفة...",
  "التعلم يبني الطريق للتميز...",
  "الدراسة تصقل الذهن...",
  "العلم يمنح الحياة قيمة...",
  "العلم سلاح الشخص القوي...",
  "التحصيل يحقق الأحلام...",
  "الدراسة تفتح الأفق...",
  "التعلم يصقل العقل...",
  "المعرفة تنمي الذكاء...",
  "العلم يجعل الحياة ممتعة...",
  "التفاني يحقق النجاح...",
  "العلم يفتح أبواب الفرص...",
  "التحصيل يصنع القادة...",
  "التعلم يحقق الإبداع...",
  "العقل النشط يزرع النجاح...",
  "الدراسة تشعل الإلهام...",
  "المعرفة تنير الطريق...",
  "التحصيل يزرع الثقة...",
  "العلم يحقق التميز...",
  "التفوق ينبع من الجهد...",
  "العلم يغذي الروح...",
  "الدراسة تشكل الشخصية...",
  "التحصيل يصنع الفرق...",
  "التعلم يزيد القوة...",
  "العلم يصنع الأبطال...",
  "التحصيل يبني المستقبل...",
  "الدراسة تنمي الحكمة...",
  "العلم يمنح الحياة طعمًا...",
  "التحصيل يحدث التغيير...",
  "التعلم يفتح الأبواب...",
  "العقل النشط يزرع النجاح...",
  "الدراسة تحقق الأحلام...",
  "العلم يصقل الشخصية..."
];
