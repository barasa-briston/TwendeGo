import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CheckoutProgressIndicator extends StatelessWidget {
  final int currentStep; // 1: Seats, 2: Details, 3: Payment

  const CheckoutProgressIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        
        return Container(
          width: double.infinity,
          color: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: isNarrow ? 16 : 24, 
            horizontal: isNarrow ? 16 : 40,
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Row(
                children: [
                  _buildStep(1, 'Select Seats', currentStep >= 1, isNarrow: isNarrow),
                  _buildLine(currentStep > 1),
                  _buildStep(2, 'Passenger Details', currentStep >= 2, isNarrow: isNarrow),
                  _buildLine(currentStep > 2),
                  _buildStep(3, 'Payment', currentStep >= 3, isNarrow: isNarrow),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(int step, String title, bool isCompleted, {bool isNarrow = false}) {
    final bool isActive = step == currentStep;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isNarrow ? 28 : 32,
          height: isNarrow ? 28 : 32,
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
                ? Icon(Icons.check, size: isNarrow ? 14 : 18, color: Colors.black)
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: isCompleted ? Colors.black : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: isNarrow ? 12 : 14,
                    ),
                  ),
          ),
        ),
        if (!isNarrow) ...[
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
