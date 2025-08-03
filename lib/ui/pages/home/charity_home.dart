import 'package:edonation/ui/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';


class CharityHome extends StatefulWidget {
  const CharityHome({super.key});

  @override
  State<CharityHome> createState() => _CharityHomeState();
}

class _CharityHomeState extends State<CharityHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      
    );
  }
}