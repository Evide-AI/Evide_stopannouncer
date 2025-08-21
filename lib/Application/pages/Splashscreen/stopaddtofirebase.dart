import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Stopaddtofirebase extends StatelessWidget {
  const Stopaddtofirebase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              addstopdetailsToFirebase();
            },
            child: Text('Add Stop'),
          ),
        ],
      ),
    );
  }
}

Future<void> addstopdetailsToFirebase() async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  await _firestore.collection('Screens').doc('b30XR5zSypPBMEsXSlXI').set({
    'stops': tirTOkuttp,
    "Contents": contentstoapp,
    "pairingCode": "12345",
    "busName": "Madeena",
  });
}

final contentstoapp = [
  {
    "duration": "33",
    "type": "video",
    "title": "Atless",
    "url":
        "gs://evide-ai-2b3d2.firebasestorage.app/video/Atlas Onam perinthalmann & kadakkal 34 SEC (video-converter.com).mp4",
  },
  {
    "duration": "52",
    "type": "video",
    "title": "Gmart",
    "url":
        "gs://evide-ai-2b3d2.firebasestorage.app/video/FAMILY + FULL SONG + GFX 50sec (video-converter.com).mp4",
  },
  {
    "duration": "5",
    "type": "image",
    "title": "Welcome",
    "url": "gs://evide-ai-2b3d2.firebasestorage.app/images/Welcome.png",
  },
  {
    "duration": "30",
    "type": "video",
    "title": "evaas",
    "url": "gs://evide-ai-2b3d2.firebasestorage.app/video/IMG_5322 (video-converter.com).mp4",
  },
];

final tirTOkuttp = [
  {
    "stopname": "Tirur stand",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/tirur stand.mp3",
    "latitude": 10.918197,
    "longitude": 75.922292,
  },
  {
    "stopname": "City",
    "stopUrl": "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/city.mp3",
    "latitude": 10.91488462,
    "longitude": 75.92293343,
  },
  {
    "stopname": "Thazhepalam",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/thazhepalam.mp3",
    "latitude": 10.91233262,
    "longitude": 75.91937014,
  },
  {
    "stopname": "Pongottukulam",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/pongottulam.mp3",
    "latitude": 10.9083502,
    "longitude": 75.9204388,
  },
  {
    "stopname": "KG padi",
    "stopUrl": "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/kg padi.mp3",
    "latitude": 10.90604,
    "longitude": 75.9210088,
  },
  {
    "stopname": "Pottethapadi",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/pottathapadi.mp3",
    "latitude": 10.9025588,
    "longitude": 75.9227422,
  },
  {
    "stopname": "Police line",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/police line.mp3",
    "latitude": 10.9008857,
    "longitude": 75.9258026,
  },
  {
    "stopname": "Panjami",
    "stopUrl": "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/panjami.mp3",
    "latitude": 10.8990358,
    "longitude": 75.9262005,
  },
  {
    "stopname": "Boys school",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/boys school.mp3",
    "latitude": 10.8954491,
    "longitude": 75.9277693,
  },
  {
    "stopname": "Vishwas",
    "stopUrl": "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/vishwas.mp3",
    "latitude": 10.89156,
    "longitude": 75.929169,
  },
  {
    "stopname": "North BP angadi",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/bp angadi.mp3",
    "latitude": 10.8889322,
    "longitude": 75.9299365,
  },
  {
    "stopname": "K R auditorium",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/kr auditorium.mp3",
    "latitude": 10.884056,
    "longitude": 75.934957,
  },
  {
    "stopname": "Pallipadi",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/pallipadi.mp3",
    "latitude": 10.883209,
    "longitude": 75.936787,
  },
  {
    "stopname": "Kannamkulam",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/kannamkulam.mp3",
    "latitude": 10.8829515,
    "longitude": 75.9423551,
  },
  {
    "stopname": "Musliar angadi",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/musliyar angadi.mp3",
    "latitude": 10.8814716,
    "longitude": 75.9455667,
  },
  {
    "stopname": "Kolupalam",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/kolupalam.mp3",
    "latitude": 10.8808875,
    "longitude": 75.9483609,
  },
  {
    "stopname": "Laksham veedu",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/lakshamveedu.mp3",
    "latitude": 10.877349,
    "longitude": 75.952091,
  },
  {
    "stopname": "Karathur",
    "stopUrl": "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/karathur.mp3",
    "latitude": 10.8737875,
    "longitude": 75.9560388,
  },
  {
    "stopname": "Avasana karathur",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/avasana karathur.mp3",
    "latitude": 10.870022,
    "longitude": 75.961172,
  },
  {
    "stopname": "Ajithapadi",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/ajithapadi.mp3",
    "latitude": 10.8672853,
    "longitude": 75.9674264,
  },
  {
    "stopname": "Codacal",
    "stopUrl": "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/kodakkal.mp3",
    "latitude": 10.8638178,
    "longitude": 75.9710849,
  },
  {
    "stopname": "Thirunnnavaya",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/thirunnavazha.mp3",
    "latitude": 10.8658905,
    "longitude": 75.9844705,
  },
  {
    "stopname": "Navamukundha school",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/navamukunda school.mp3",
    "latitude": 10.8656478,
    "longitude": 75.9902235,
  },
  {
    "stopname": "Pallipadi",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/pallipadi.mp3",
    "latitude": 10.86743164,
    "longitude": 75.99566028,
  },
  {
    "stopname": "Rangattoor",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/rangatoor.mp3",
    "latitude": 10.8674657,
    "longitude": 76.0013265,
  },
  {
    "stopname": "Company padi",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/company padi.mp3",
    "latitude": 10.866965,
    "longitude": 76.005374,
  },
  {
    "stopname": "Chembikkal",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/chembikkal.mp3",
    "latitude": 10.8640384,
    "longitude": 76.0143185,
  },
  {
    "stopname": "Nila park",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/nila park.mp3",
    "latitude": 10.84711802,
    "longitude": 76.03013268,
  },
  {
    "stopname": "Kuttippuram stand",
    "stopUrl":
        "gs://evide-ai-2b3d2.firebasestorage.app/stopAudio/kuttippuram stand.mp3",
    "latitude": 10.8443729,
    "longitude": 76.0337333,
  },
];
