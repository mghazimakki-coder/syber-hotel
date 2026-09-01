import 'package:flutter/material.dart';
import '../models/hotel.dart';


class BookingScreen extends StatelessWidget {

  final Hotel hotel;


  const BookingScreen({
    super.key,
    required this.hotel,
  });


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('Booking'),
      ),


      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text(
              hotel.name,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),


            const SizedBox(height: 20),


            Text(
              "Location: ${hotel.location}",
              style: const TextStyle(
                fontSize: 18,
              ),
            ),


            const SizedBox(height: 10),


            Text(
              "Price: ${hotel.price}",
              style: const TextStyle(
                fontSize: 18,
              ),
            ),


            const SizedBox(height: 30),


            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                onPressed: () {

                  ScaffoldMessenger.of(context)
                      .showSnackBar(

                    const SnackBar(

                      content: Text(
                        "Booking Confirmed",
                      ),

                    ),

                  );

                },


                child: const Text(
                  "Confirm Booking",
                ),

              ),

            ),


          ],

        ),

      ),

    );

  }

}