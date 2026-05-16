import 'package:flutter/material.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/item_category_chip.dart';
import 'package:campus_lost_found/features/post/domain/entities/item_taxonomy.dart';

const _kAmber = Color(0xFFCA8A04);
const _kAmberLight = Color(0xFFFEF3C7);

class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.errorText,
  });

  final ItemTaxonomy? selected;
  final ValueChanged<ItemTaxonomy> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.95,
          ),
          itemCount: ItemTaxonomy.values.length,
          itemBuilder: (context, index) {
            final taxonomy = ItemTaxonomy.values[index];
            final isSelected = taxonomy == selected;
            return GestureDetector(
              onTap: () => onChanged(taxonomy),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? _kAmberLight : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? _kAmber : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _kAmber.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      taxonomy.iconData,
                      size: 22,
                      color: isSelected ? _kAmber : Colors.grey.shade500,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      taxonomy.displayNameEn,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF92400E) : Colors.grey.shade700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
