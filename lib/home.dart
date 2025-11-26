import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // header
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      size: 48,
                      color: Colors.black,
                    ),
                    padding: EdgeInsets.all(0),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Nov. 2025',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      size: 48,
                      color: Colors.black,
                    ),
                    padding: EdgeInsets.all(0),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton.filled(
                  onPressed: () {},
                  icon: Icon(
                    Icons.bar_chart,
                    size: 36,
                    color: Colors.black,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Text(
              "Today Spent",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF0000BB),
              ),
            ),
            Text(
              "\$ 33.4",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0000BB),
              ),
            ),
            Text(
              "Daily limit: Under \$50",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF0000BB),
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double maxHeight = constraints.maxHeight;
              final double limitMoneyHeight = maxHeight * 0.68;
              final double spentMoneyHeight = maxHeight * 0.1;

              return ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: screenWidth * 0.38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      width: screenWidth * 0.38,
                      height: spentMoneyHeight,
                      decoration: BoxDecoration(
                        color: Color(0xFF0000BB),
                      ),
                    ),
                    Container(
                      width: screenWidth * 0.38,
                      height: limitMoneyHeight,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.black,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: 24),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 24),
                Text(
                  "Target Monthly Max",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.edit,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Text(
              "1,500,000",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: 36),
      ],
    );
  }
}
