#!/usr/bin/env python3
"""Create contact and organization XLSX registers."""

from create_finance_templates import ROOT, create_workbook


def main() -> None:
    create_workbook(
        ROOT / "contacts" / "contacts.xlsx",
        [
            "ID",
            "Имя",
            "Телефон",
            "Тип контакта",
            "Организация / дом",
            "Роль",
            "Язык",
            "Предпочтительный канал",
            "Источник",
            "Можно писать?",
            "Последний контакт",
            "Статус",
            "Комментарий",
        ],
        [14, 26, 18, 18, 28, 22, 14, 22, 28, 16, 18, 16, 42],
        force=False,
    )
    create_workbook(
        ROOT / "contacts" / "organizations.xlsx",
        [
            "ID",
            "Название / дом",
            "Тип",
            "Адрес",
            "Связанные контакты",
            "Общий телефон",
            "Статус",
            "Последний контакт",
            "Комментарий",
        ],
        [14, 30, 20, 34, 34, 18, 16, 18, 44],
        force=False,
    )


if __name__ == "__main__":
    main()
