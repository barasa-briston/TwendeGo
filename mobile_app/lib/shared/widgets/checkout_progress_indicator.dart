import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CheckoutProgressIndicator extends StatelessWidget {
  final int currentStep; // 1: Seats, 2: Details, 3: Payment

  const CheckoutProgressIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Row(
            children: [
              _buildStep(1, 'Select Seats', currentStep >= 1),
              _buildLine(currentStep > 1),
              _buildStep(2, 'Passenger Details', currentStep >= 2),
              _buildLine(currentStep > 2),
              _buildStep(3, 'Payment', currentStep >= 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int step, String title, bool isCompleted) {
    final bool isActive = step == currentStep;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted ? AppColors.primary : AppColors.divider,
              width: 2,
            ),
            boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)] : [],
          ),
          child: Center(
            child: isCompleted && step < currentStep
                ? const Icon(Icons.check, size: 18, color: Colors.black)
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: isCompleted ? Colors.black : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: isCompleted ? AppColors.primary : AppColors.divider,
      ),
    );
  }
}
