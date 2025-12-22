import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class Detail extends StatefulWidget {
  const Detail({super.key});

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        size: 48,
                        color: Colors.black,
                      ),
                      padding: const EdgeInsets.all(0),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Dec. 2025",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        size: 48,
                        color: Colors.black,
                      ),
                      padding: const EdgeInsets.all(0),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton.filled(
                    onPressed: () {},
                    icon: Icon(
                      Icons.calendar_month_rounded,
                      size: 28,
                      color: Colors.black,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.all(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          ListView.builder(
            itemCount: 10,
            itemBuilder: (BuildContext ctx, int idx) {
              return Column(
                children: [
                  Text("Hello"),
                  ListView.builder(
                    itemCount: 10,
                    itemBuilder: (BuildContext ctx, int idx) {
                      return Text("123");
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
