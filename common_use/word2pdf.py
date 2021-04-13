#!/usr/bin/python
# -*- coding: utf-8 -*-


from win32com.client import gencache
from win32com.client import constants, gencache

def createPdf(wordPath, pdfPath):
  """
  word转pdf
  :param wordPath: word文件路径
  :param pdfPath: 生成pdf文件路径
  """
  word = gencache.EnsureDispatch('Word.Application')
  doc = word.Documents.Open(wordPath, ReadOnly=1)
  doc.ExportAsFixedFormat(pdfPath,
              constants.wdExportFormatPDF,
              Item=constants.wdExportDocumentWithMarkup,
              CreateBookmarks=constants.wdExportCreateHeadingBookmarks)
  word.Quit(constants.wdDoNotSaveChanges)

wordPath = r'H:\python3\project\test\0413\20210413_RNA_PBK_42_肺泡灌洗液-DNA(RNA_PBK_42)_PRI-seq纳米孔测序病原宏基因组学检测报告.docx'
pdfPath = r'H:\python3\project\test\0413\20210413_RNA_PBK_42_肺泡灌洗液-DNA(RNA_PBK_42)_PRI-seq纳米孔测序病原宏基因组学检测报告.pdf'

createPdf(wordPath,pdfPath)